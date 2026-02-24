
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS VoteScore, 
        DATE_TRUNC('month', p.CreationDate) AS MonthYear
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, DATE_TRUNC('month', p.CreationDate)
),
AverageStats AS (
    SELECT 
        MonthYear,
        AVG(CommentCount) AS AvgComments,
        AVG(VoteScore) AS AvgVoteScore
    FROM 
        PostStats
    GROUP BY 
        MonthYear
)
SELECT 
    MonthYear,
    AvgComments,
    AvgVoteScore
FROM 
    AverageStats
ORDER BY 
    MonthYear DESC;
