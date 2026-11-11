# Workforce Management Queue Performance Analysis

## Overview

This SQL project analyzes contact-center queue performance from 2024 through November 2026. It examines how staffing availability, occupancy, demand, wait time, absenteeism, PTO, and forecast accuracy relate to long-call abandonment.

## Business Objective

Identify the conditions associated with elevated long-abandonment rates and highlight months that need operational review.

## Dataset

The analysis combines two datasets:

- `Queue_Data.csv` — monthly call demand, abandonment, service level, wait time, handling time, occupancy, and forecast data.
- `Staffing.csv` — daily Lex and ICT scheduled hours, absences, and PTO data.

## Key Metric

**Long abandonment rate** excludes short abandons:

```sql
((aba_calls - short_aba) / offered_calls) * 100
```

## Key Findings

- **November 2026** had the highest long-abandonment rate at **8.8%**.
- Other high-risk months included **September 2024 (7.1%)**, **October 2026 (6.7%)**, **June 2026 (6.6%)**, and **October 2024 (6.5%)**.
- The 2026 year-to-date average long-abandonment rate was **5.1%**.
- High abandonment generally appeared alongside elevated occupancy and longer customer waits.
- October and November 2026 should be prioritized for operational review.

## Analysis Questions

This project answers questions such as:

1. Which months had the greatest long-abandonment rate?
2. Which months exceeded the 5% abandonment threshold?
3. How did demand per scheduled hour relate to abandonment?
4. Did wait time, occupancy, absenteeism, PTO, and forecast variance align with higher abandonment?
5. Which calendar months show the highest average abandonment across years?

## Tools Used

- MySQL
- SQL aggregation and joins
- Subqueries
- `CASE` statements
- KPI calculations

## Repository Structure

```text
├── data/
│   ├── Queue_Data.csv
│   └── Staffing.csv
├── sql/
│   └── workforce_management_analysis.sql
└── README.md
```

## Author

Derron G. Britton
