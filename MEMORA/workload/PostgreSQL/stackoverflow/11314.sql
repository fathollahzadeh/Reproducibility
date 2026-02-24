WITH PostTypeCount AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),


AvgPostScore AS (
    SELECT 
        pt.Name AS PostTypeName,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),


CommentCount AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)


SELECT 
    ptc.PostTypeName,
    ptc.PostCount,
    aps.AverageScore,
    cc.CommentCount
FROM 
    PostTypeCount ptc
JOIN 
    AvgPostScore aps ON ptc.PostTypeName = aps.PostTypeName
JOIN 
    CommentCount cc ON ptc.PostTypeName = cc.PostTypeName
ORDER BY 
    ptc.PostTypeName;