SELECT tt1.tid AS tid
     , tt1.yy AS yy
     , 0 AS mm
     , LPAD(tt1.yy, 4, '0') AS mo
     , CAST(IFNULL(fuel_cnt, 0)    AS DECIMAL(19,0)) AS fuel_cnt
     , CAST(IFNULL(fuel_min, 0)    AS DECIMAL(19,2)) AS fuel_min
     , CAST(IFNULL(fuel_avg, 0)    AS DECIMAL(19,2)) AS fuel_avg
     , CAST(IFNULL(fuel_max, 0)    AS DECIMAL(19,2)) AS fuel_max
     , CAST(IFNULL(fuel_sum, 0)    AS DECIMAL(19,2)) AS fuel_sum
     , CAST(IFNULL(mileage_cnt, 0) AS DECIMAL(19,0)) AS mileage_cnt
     , CAST(IFNULL(mileage_min, 0) AS DECIMAL(19,0)) AS mileage_min
     , CAST(IFNULL(mileage_avg, 0) AS DECIMAL(19,0)) AS mileage_avg
     , CAST(IFNULL(mileage_max, 0) AS DECIMAL(19,0)) AS mileage_max
     , CAST(IFNULL(mileage_sum, 0) AS DECIMAL(19,0)) AS mileage_sum
     , CAST(IFNULL(fuel_sum/mileage_sum*100, 0) AS DECIMAL(9,2)) AS fm_sum
  FROM (
        SELECT tid, yy, fuel_cnt, fuel_min, fuel_avg, fuel_max, fuel_sum
          FROM (SELECT t1.tid, t1.yy, t2.fuel_cnt, t2.fuel_min, t2.fuel_avg, t2.fuel_max, fuel_sum
                  FROM (SELECT 121 AS tid, yy
                          FROM list_y
                         WHERE yyyy BETWEEN (SELECT DATE_FORMAT(MIN(date), '%Y') FROM fuel WHERE tid = 121)
                                        AND (SELECT DATE_FORMAT(MAX(date), '%Y') FROM fuel WHERE tid = 121)) AS t1
     LEFT JOIN (SELECT tid, yy, COUNT(*) AS fuel_cnt, MIN(fuel) AS fuel_min
                     , AVG(fuel) AS fuel_avg, MAX(fuel) AS fuel_max, SUM(fuel) AS fuel_sum
                  FROM (SELECT tid, YEAR(date) AS yy, fuel
                          FROM argodb.fuel) AS t1
                 GROUP BY tid, yy) AS t2
            ON t1.tid = t2.tid AND t1.yy = t2.yy) AS t9
         WHERE tid = 121
       ) AS tt1
  JOIN (
        SELECT tid, yy, mileage_cnt, mileage_min, mileage_avg, mileage_max, mileage_sum
          FROM (SELECT t3.tid, t3.yy, t4.mileage_cnt, t4.mileage_min, t4.mileage_avg, t4.mileage_max, t4.mileage_sum
                  FROM (SELECT 121 AS tid, yy
                          FROM list_y
                         WHERE yyyy BETWEEN (SELECT DATE_FORMAT(MIN(date), '%Y') FROM mileage WHERE tid = 121)
                                        AND (SELECT DATE_FORMAT(MAX(date), '%Y') FROM mileage WHERE tid = 121)) AS t3
     LEFT JOIN (SELECT tid, yy, COUNT(*) AS mileage_cnt
                     , MIN(mileage) AS mileage_min, AVG(mileage) AS mileage_avg
                     , MAX(mileage) AS mileage_max, SUM(mileage) AS mileage_sum
                  FROM (SELECT 121 AS tid, YEAR(t2.date) AS yy, t2.mileage - t1.mileage AS mileage
                          FROM (SELECT (@row_number_1 := @row_number_1 + 1) AS rid, m1.*
                                  FROM mileage AS m1, (SELECT @row_number_1 := 0) AS x
                                 WHERE tid = 121 ORDER BY rid) AS t1
                     LEFT JOIN (SELECT (@row_number_2 := @row_number_2 + 1) AS rid, m1.*
                                  FROM mileage AS m1, (SELECT @row_number_2 := 0) AS x
                                 WHERE tid = 121 ORDER BY rid) AS t2
                            ON t1.rid = t2.rid - 1
                         WHERE t2.rid IS NOT NULL 
                         ORDER BY t1.rid, t2.rid) AS t
                 GROUP BY tid, yy) AS t4
            ON t3.tid = t4.tid AND t3.yy = t4.yy) AS t
         WHERE tid = 121
       ) AS tt2
    ON tt1.tid = tt2.tid AND tt1.yy = tt2.yy
 ORDER BY tt1.yy ASC
