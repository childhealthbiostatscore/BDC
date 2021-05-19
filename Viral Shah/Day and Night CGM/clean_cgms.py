import os
import pathlib
import pandas as pd
import numpy as np
import datetime
from dateutil.parser import parse
from sklearn import metrics
# Import data
wd = '/Users/timvigers/Dropbox/Work/Viral Shah/Day and Night CGM/'
# Most recent HbA1c information
a1cs = pd.read_csv(wd+'Data_Clean/a1cs.csv',parse_dates=['MostRecentVisitDate'])
# Iterate through CGM files, match with row in a1cs df, calculate metrics
# Dictionary for storing results
df = {'id':[],'gender':[],'age': [],'insulin':[],'hba1c':[],
     'day_auc':[],'day_tir':[],'night_auc':[],'night_tir':[]}
# Iterate through files in wd
for file in os.listdir(wd+'Data_Clean/cgms/'):
    print(file)
    # File extensioncontinueading in
    ext = pathlib.Path(wd+'Data_Raw/Patient 90 days/'+file).suffix
    if 'xls' in ext:
        d = pd.read_excel(wd+'Data_Raw/Patient 90 days/'+file)
    elif 'csv' in ext:
        d = pd.read_csv(wd+'Data_Raw/Patient 90 days/'+file)
    # Identify type of CGM file
    if 'Patient Info' in d.columns:
        # Pull A1c and dempgraphic data 
        n = d['Patient Info'].iloc[0].lower()+'_'+d['Patient Info'].iloc[1].lower()
        mask = a1cs['ID'].isin([n])
        r = a1cs.loc[mask]
        # Get cgm data
        time = d['Timestamp (YYYY-MM-DDThh:mm:ss)']
        time = [parse(t.replace("T"," ")) if type(t) == str else t for t in time]
        gluc = d['Glucose Value (mg/dL)']
        cgm = pd.concat([pd.Series(time), gluc], axis=1)
        cgm.columns = ['time','glucose']
    else:
        print("Wrong columns")
        break
    # Get CGM data two weeks from HbA1c
    end = r['MostRecentVisitDate'].iloc[0]
    start = end - datetime.timedelta(days = 14)
    cgm = cgm[(cgm['time'] >= start) & (cgm['time'] < end)]
    cgm = cgm[(cgm['glucose'] != 'Low') & (cgm['glucose'] != 'High')]
    cgm['glucose'] = pd.to_numeric(cgm['glucose'])
    cgm.set_index('time',inplace=True,drop=False)
    # Calculate CGM metrics
    day = cgm.between_time("6:00","23:00",include_start=False,include_end=False)
    night = cgm.between_time("23:00","6:00")
    # Add dempgraphic information
    df['id'].append(n)
    df['gender'].append(r['Gender'].iloc[0])
    df['age'].append(r['Age'].iloc[0])
    df['insulin'].append(r['InsulinRegimen'].iloc[0])
    df['hba1c'].append(r['MostRecentA1C'].iloc[0])
    df['day_auc'].append(np.trapz(day['glucose'],pd.to_numeric(day['time'])))
    df['day_tir'].append(len([g for g in day['glucose'] if g >=70 and g < 180])/day.shape[0]*100)
    df['night_auc'].append(np.trapz(night['glucose'],pd.to_numeric(night['time'])))
    df['night_tir'].append(len([g for g in night['glucose'] if g >=70 and g < 180])/night.shape[0]*100)