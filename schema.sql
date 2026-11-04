-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.roles (
  role_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  role_name character varying NOT NULL UNIQUE,
  CONSTRAINT roles_pkey PRIMARY KEY (role_id)
);
CREATE TABLE public.users (
  user_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  username character varying NOT NULL UNIQUE,
  role_id bigint NOT NULL,
  email character varying NOT NULL UNIQUE,
  password character varying NOT NULL,
  is_archived boolean NOT NULL,
  CONSTRAINT users_pkey PRIMARY KEY (user_id),
  CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id)
);
CREATE TABLE public.positions (
  position_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  position_name character varying NOT NULL UNIQUE,
  CONSTRAINT positions_pkey PRIMARY KEY (position_id)
);
CREATE TABLE public.employees (
  employee_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id bigint NOT NULL UNIQUE,
  first_name character varying NOT NULL,
  last_name character varying NOT NULL,
  contact_no character varying NOT NULL,
  hire_date date NOT NULL,
  hourly_rate numeric NOT NULL,
  employee_status character varying NOT NULL,
  position_id bigint NOT NULL,
  CONSTRAINT employees_pkey PRIMARY KEY (employee_id),
  CONSTRAINT employees_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT employees_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(position_id)
);
CREATE TABLE public.branches (
  branch_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  branch_name character varying NOT NULL UNIQUE,
  address character varying NOT NULL,
  branch_manager_id bigint NOT NULL,
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  geofence_radius_m smallint NOT NULL,
  CONSTRAINT branches_pkey PRIMARY KEY (branch_id),
  CONSTRAINT branches_branch_manager_id_fkey FOREIGN KEY (branch_manager_id) REFERENCES public.employees(employee_id)
);
CREATE TABLE public.employee_branch (
  employee_branch_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  employee_id bigint NOT NULL,
  branch_id bigint NOT NULL,
  is_primary boolean NOT NULL,
  CONSTRAINT employee_branch_pkey PRIMARY KEY (employee_branch_id),
  CONSTRAINT employee_branch_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id),
  CONSTRAINT employee_branch_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id)
);
CREATE TABLE public.shift_types (
  shift_type_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  shift_name character varying NOT NULL UNIQUE,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  break_minutes bigint NOT NULL,
  is_overnight boolean NOT NULL,
  CONSTRAINT shift_types_pkey PRIMARY KEY (shift_type_id)
);
CREATE TABLE public.scheduling_rules (
  scheduling_rule_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  branch_id bigint NOT NULL,
  rule_name character varying NOT NULL,
  rule_value character varying NOT NULL,
  CONSTRAINT scheduling_rules_pkey PRIMARY KEY (scheduling_rule_id),
  CONSTRAINT scheduling_rules_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id)
);
CREATE TABLE public.staffing_requirements (
  requirement_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  branch_id bigint NOT NULL,
  shift_type_id bigint NOT NULL,
  day_of_week character varying NOT NULL,
  min_staff smallint NOT NULL,
  position_id bigint NOT NULL,
  CONSTRAINT staffing_requirements_pkey PRIMARY KEY (requirement_id),
  CONSTRAINT staffing_requirements_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id),
  CONSTRAINT staffing_requirements_shift_type_id_fkey FOREIGN KEY (shift_type_id) REFERENCES public.shift_types(shift_type_id),
  CONSTRAINT staffing_requirements_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(position_id)
);
CREATE TABLE public.schedules_header (
  schedule_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  generated_by bigint NOT NULL,
  branch_id bigint NOT NULL,
  week_start date NOT NULL,
  schedule_status character varying NOT NULL,
  publishes_at timestamp with time zone DEFAULT now(),
  CONSTRAINT schedules_header_pkey PRIMARY KEY (schedule_id),
  CONSTRAINT schedules_header_generated_by_fkey FOREIGN KEY (generated_by) REFERENCES public.users(user_id),
  CONSTRAINT schedules_header_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id)
);
CREATE TABLE public.schedule_details (
  detail_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  schedule_header_id bigint NOT NULL,
  employee_id bigint NOT NULL,
  shift_type_id bigint NOT NULL,
  shift_date date NOT NULL,
  CONSTRAINT schedule_details_pkey PRIMARY KEY (detail_id),
  CONSTRAINT schedule_details_schedule_header_id_fkey FOREIGN KEY (schedule_header_id) REFERENCES public.schedules_header(schedule_id),
  CONSTRAINT schedule_details_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id),
  CONSTRAINT schedule_details_shift_type_id_fkey FOREIGN KEY (shift_type_id) REFERENCES public.shift_types(shift_type_id)
);
CREATE TABLE public.shift_swap_requests (
  shift_swap_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  requester_detail_id bigint NOT NULL,
  target_detail_id bigint NOT NULL,
  swap_status character varying NOT NULL,
  reviewed_by bigint,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT shift_swap_requests_pkey PRIMARY KEY (shift_swap_id),
  CONSTRAINT shift_swap_request_requester_detail_id_fkey FOREIGN KEY (requester_detail_id) REFERENCES public.schedule_details(detail_id),
  CONSTRAINT shift_swap_request_target_detail_id_fkey FOREIGN KEY (target_detail_id) REFERENCES public.schedule_details(detail_id),
  CONSTRAINT shift_swap_request_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(user_id)
);
CREATE TABLE public.attendance (
  attendance_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  schedule_detail_id bigint NOT NULL UNIQUE,
  time_in timestamp with time zone DEFAULT now(),
  time_out timestamp with time zone DEFAULT now(),
  in_latitude numeric,
  in_longitude numeric,
  out_latitude numeric,
  out_longitude numeric,
  remarks text,
  CONSTRAINT attendance_pkey PRIMARY KEY (attendance_id),
  CONSTRAINT attendance_schedule_detail_id_fkey FOREIGN KEY (schedule_detail_id) REFERENCES public.schedule_details(detail_id)
);
CREATE TABLE public.attendance_corrections (
  attendance_correction_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  schedule_detail_id bigint NOT NULL,
  requested_time_in timestamp with time zone NOT NULL,
  requested_time_out timestamp with time zone NOT NULL,
  reason text NOT NULL,
  correction_status character varying NOT NULL,
  reviewed_by bigint,
  requested_at timestamp with time zone NOT NULL,
  reviewed_at timestamp with time zone,
  CONSTRAINT attendance_corrections_pkey PRIMARY KEY (attendance_correction_id),
  CONSTRAINT attendance_corrections_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(user_id),
  CONSTRAINT attendance_corrections_schedule_detail_id_fkey FOREIGN KEY (schedule_detail_id) REFERENCES public.schedule_details(detail_id)
);
CREATE TABLE public.leave_types (
  leave_type_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  leave_name character varying NOT NULL UNIQUE,
  is_paid boolean NOT NULL,
  default_days_per_year integer NOT NULL,
  CONSTRAINT leave_types_pkey PRIMARY KEY (leave_type_id)
);
CREATE TABLE public.leave_balances (
  leave_balance_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  employee_id bigint NOT NULL,
  leave_type_id bigint NOT NULL,
  leave_year integer NOT NULL,
  allocated_days integer NOT NULL,
  CONSTRAINT leave_balances_pkey PRIMARY KEY (leave_balance_id),
  CONSTRAINT leave_balances_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id),
  CONSTRAINT leave_balances_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(leave_type_id)
);
CREATE TABLE public.leave_requests (
  leave_request_id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  employee_id bigint NOT NULL,
  leave_type_id bigint NOT NULL,
  reviewed_by bigint,
  start_date date NOT NULL,
  end_date date NOT NULL,
  reason text NOT NULL,
  leave_request_status character varying NOT NULL,
  days_count integer NOT NULL,
  CONSTRAINT leave_requests_pkey PRIMARY KEY (leave_request_id),
  CONSTRAINT leave_requests_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id),
  CONSTRAINT leave_requests_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES public.leave_types(leave_type_id),
  CONSTRAINT leave_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(user_id)
);
CREATE TABLE public.cash_advances (
  cash_advance_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  employee_id bigint NOT NULL,
  amount numeric NOT NULL,
  cash_advance_date date NOT NULL,
  cash_advance_status character varying NOT NULL,
  approved_by bigint,
  CONSTRAINT cash_advances_pkey PRIMARY KEY (cash_advance_id),
  CONSTRAINT cash_advances_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id),
  CONSTRAINT cash_advances_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(user_id)
);
CREATE TABLE public.earning_types (
  earning_type_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  earning_name character varying NOT NULL UNIQUE,
  CONSTRAINT earning_types_pkey PRIMARY KEY (earning_type_id)
);
CREATE TABLE public.deduction_types (
  deduction_type_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  deduction_name character varying NOT NULL UNIQUE,
  CONSTRAINT deduction_types_pkey PRIMARY KEY (deduction_type_id)
);
CREATE TABLE public.payroll_periods (
  period_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  payroll_period_status character varying NOT NULL,
  pay_date date NOT NULL,
  CONSTRAINT payroll_periods_pkey PRIMARY KEY (period_id)
);
CREATE TABLE public.payroll_headers (
  payroll_header_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  period_id bigint NOT NULL,
  employee_id bigint NOT NULL,
  payroll_status character varying NOT NULL,
  hourly_rate numeric NOT NULL,
  prepared_by bigint NOT NULL,
  generated_at timestamp with time zone NOT NULL,
  published_at timestamp with time zone,
  remarks text,
  CONSTRAINT payroll_headers_pkey PRIMARY KEY (payroll_header_id),
  CONSTRAINT payroll_headers_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.payroll_periods(period_id),
  CONSTRAINT payroll_headers_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id),
  CONSTRAINT payroll_headers_prepared_by_fkey FOREIGN KEY (prepared_by) REFERENCES public.users(user_id)
);
CREATE TABLE public.payroll_details (
  payroll_detail_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  payroll_header_id bigint NOT NULL,
  attendance_id bigint NOT NULL,
  regular_hours numeric NOT NULL,
  overtime_hours numeric NOT NULL,
  CONSTRAINT payroll_details_pkey PRIMARY KEY (payroll_detail_id),
  CONSTRAINT payroll_details_payroll_header_id_fkey FOREIGN KEY (payroll_header_id) REFERENCES public.payroll_headers(payroll_header_id),
  CONSTRAINT payroll_details_attendance_id_fkey FOREIGN KEY (attendance_id) REFERENCES public.attendance(attendance_id)
);
CREATE TABLE public.payroll_earnings (
  payroll_earning_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  payroll_header_id bigint NOT NULL,
  earning_type_id bigint NOT NULL,
  leave_request_id bigint,
  amount numeric NOT NULL,
  CONSTRAINT payroll_earnings_pkey PRIMARY KEY (payroll_earning_id),
  CONSTRAINT payroll_earnings_payroll_header_id_fkey FOREIGN KEY (payroll_header_id) REFERENCES public.payroll_headers(payroll_header_id),
  CONSTRAINT payroll_earnings_leave_request_id_fkey FOREIGN KEY (leave_request_id) REFERENCES public.leave_requests(leave_request_id),
  CONSTRAINT payroll_earnings_earning_type_id_fkey FOREIGN KEY (earning_type_id) REFERENCES public.earning_types(earning_type_id)
);
CREATE TABLE public.payroll_deductions (
  payroll_deduction_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  payroll_header_id bigint NOT NULL,
  deduction_type_id bigint,
  amount numeric NOT NULL,
  cash_advance_id bigint,
  CONSTRAINT payroll_deductions_pkey PRIMARY KEY (payroll_deduction_id),
  CONSTRAINT payroll_deductions_payroll_header_id_fkey FOREIGN KEY (payroll_header_id) REFERENCES public.payroll_headers(payroll_header_id),
  CONSTRAINT payroll_deductions_deduction_type_id_fkey FOREIGN KEY (deduction_type_id) REFERENCES public.deduction_types(deduction_type_id),
  CONSTRAINT payroll_deductions_cash_advance_id_fkey FOREIGN KEY (cash_advance_id) REFERENCES public.cash_advances(cash_advance_id)
);
CREATE TABLE public.audit_logs (
  log_id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id bigint NOT NULL,
  action character varying NOT NULL,
  table_name character varying NOT NULL,
  record_id bigint NOT NULL,
  created_at timestamp with time zone NOT NULL,
  old_value jsonb,
  new_value jsonb,
  CONSTRAINT audit_logs_pkey PRIMARY KEY (log_id),
  CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);