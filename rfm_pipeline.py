import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def run_rfm_pipeline(sales_filepath='sales_data.csv', output_filepath='rfm_customer_segments.csv'):
    df_sales = pd.read_csv(sales_filepath)
    df_sales['order_date'] = pd.to_datetime(df_sales['order_date'])
    
    snapshot_date = df_sales['order_date'].max() + timedelta(days=1)
    
    rfm = df_sales.groupby('customer_id').agg({
        'order_date': lambda x: (snapshot_date - x.max()).days,
        'order_id': 'nunique',
        'sales_amount': 'sum',
        'profit': 'sum'
    }).reset_index()
    
    rfm.columns = ['customer_id', 'recency', 'frequency', 'monetary', 'total_profit']
    
    rfm['r_score'] = pd.qcut(rfm['recency'], 5, labels=[5, 4, 3, 2, 1]).astype(int)
    rfm['f_score'] = pd.qcut(rfm['frequency'].rank(method='first'), 5, labels=[1, 2, 3, 4, 5]).astype(int)
    rfm['m_score'] = pd.qcut(rfm['monetary'], 5, labels=[1, 2, 3, 4, 5]).astype(int)
    
    def assign_cohort(row):
        r, f, m = row['r_score'], row['f_score'], row['m_score']
        if r >= 4 and f >= 4 and m >= 4:
            return 'Champions'
        elif r >= 3 and f >= 3:
            return 'Loyal Customers'
        elif r >= 4 and f <= 2:
            return 'Promising / New'
        elif r <= 2 and f >= 3:
            return 'At Risk'
        elif r <= 2 and f <= 2:
            return 'Lost Customers'
        else:
            return 'Potential Loyalist'
            
    rfm['segment'] = rfm.apply(assign_cohort, axis=1)
    rfm.to_csv(output_filepath, index=False)
    print(f"RFM analysis completed and saved to {output_filepath}")

if __name__ == '__main__':
    run_rfm_pipeline()
