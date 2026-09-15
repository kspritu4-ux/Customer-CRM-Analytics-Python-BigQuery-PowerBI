# Customer & CRM Analytics — Brazilian E-Commerce

## 📊 Turning Customer Data into Retention Decisions

An end-to-end Customer & CRM Analytics project analyzing Brazilian E-Commerce
data by Olist to identify high-value customers, retention risks, loyalty drivers,
delivery-performance issues, and opportunities for customer growth.

The project combines **Google BigQuery, Python, RFM Analysis, and Power BI**
to transform raw transactional data into actionable business insights.

---

## 🎯 Business Problem

The analysis was designed around seven CRM questions:

1. Who are the most valuable customers?
2. Which customers are at risk of leaving?
3. Which product categories drive loyalty versus one-time purchases?
4. What is the average Customer Lifetime Value (CLV)?
5. Do delivery delays contribute to poor reviews and churn?
6. Which cities or regions have the most unhappy customers?
7. What factors influence 1-star versus 5-star reviews?

The objective was not just to visualize data, but to connect every analysis
to a specific business decision.

---

## 💡 Key Business Insights

| Business Metric | Finding |
|---|---:|
| Revenue at Risk | **R$3.74M (24%)** |
| At-Risk Customers | **21K** |
| Lost Customers | **16K** |
| Repeat Rate | **3.12%** |
| On-Time Delivery | **98%** |
| Champions | **19K** |
| Loyal Customers | **17K** |

### What These Insights Mean

- **Revenue Protection:** R$3.74M of revenue is associated with customers
  requiring retention attention.
- **Retention Opportunity:** The 3.12% repeat rate highlights substantial
  potential to improve repeat purchasing.
- **Customer Recovery:** 21K At-Risk and 16K Lost customers represent
  priority re-engagement segments.
- **Operational Performance:** 98% on-time delivery indicates strong
  delivery execution.
- **Retention Base:** Champions and Loyal customers represent the core
  customer base requiring loyalty-focused strategies.

---

## 👥 Customer Segmentation

RFM analysis was used to classify customers according to:

- **Recency** — How recently the customer purchased
- **Frequency** — How often the customer purchased
- **Monetary Value** — How much the customer spent

The RFM analysis produced six customer segments:

- Champion
- Loyal
- At Risk
- Lost
- New Customer
- Potential

The Python analysis loaded **93,470 customers** from the BigQuery RFM view. 

---

## 🤖 AI-Powered CRM Retention Strategy

After RFM segmentation, an LLM was used to develop an actionable retention
strategy for At-Risk customers.

### Predict
Use RFM and behavioral signals for AI-based churn-risk scoring.

### Re-engage
Launch personalized win-back campaigns for customers moving toward the
Lost segment.

### Convert
Use next-best-product recommendations to encourage repeat purchases.

### Reward
Create loyalty and VIP offers for Champions and Loyal customers.

### Optimize
Monitor campaign performance and reduce revenue at risk through automated
CRM actions.

The strategy also recommends customer sub-segmentation, personalized offers,
multi-channel engagement, proactive retention triggers, and measurable KPIs.

---

## 📈 Dashboard

The Power BI solution provides:

### Executive Overview 
- Total Revenue
- Customer Lifetime Value
- Total Orders
- Monthly Revenue Trend
- Order Status Distribution
- Delivery Performance

<img width="1432" height="802" alt="Screenshot 2026-09-16 014126" src="https://github.com/user-attachments/assets/5ea058a7-7c73-4665-8309-38354563bb9e" />


### Customer Segments
- RFM Segment Distribution
- Revenue Contribution
- Revenue at Risk
- Customer Segment Analysis

<img width="1438" height="802" alt="image" src="https://github.com/user-attachments/assets/4e90c3c0-6abb-436d-abb8-a7b55754e31b" />


### Delivery & Satisfaction
- On-Time Delivery
- Delivery Delay by State
- Delivery Performance Trend
- Late Orders
- Customer Rating vs Delivery Performance

<img width="1437" height="802" alt="image" src="https://github.com/user-attachments/assets/88508b5f-5033-4d60-8ea1-f00a26156ea1" />


### Product & Category
- Category Revenue
- Category Orders
- Category Average Rating
- Repeat Rate by Category
- Category Performance

<img width="1437" height="802" alt="image" src="https://github.com/user-attachments/assets/d81d9adf-53a7-4ad7-9b02-2daff3b0e08d" />

### Dashboard Overview

<img width="1437" height="801" alt="image" src="https://github.com/user-attachments/assets/76ec7293-0903-4c43-8f1a-3eff5231c726" />

---

## 🛠️ Tools & Technologies

### Data & Analytics
- **Google BigQuery**
- **SQL**
- **Python**
- **Pandas**
- **RFM Analysis**

### Visualization
- **Microsoft Power BI**
- Power BI DAX
- Interactive dashboards
- KPI cards
- Slicers
- Maps
- Trend analysis

### Python Environment
- Visual Studio / VS Code
- Jupyter Notebook

---

## 🔄 Project Workflow

```text
Raw E-Commerce Data
        ↓
Data Extraction
        ↓
Data Cleaning & Transformation
        ↓
Python Analysis
        ↓
Google BigQuery
        ↓
SQL Business Analysis
        ↓
RFM Customer Segmentation
        ↓
Power BI Data Model
        ↓
Interactive CRM Dashboard
        ↓
Business Insights
        ↓
AI-Powered Retention Strategy
