WITH PostDetails AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT v.UserId) AS UserCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        pt.Name
), 
VoteDetails AS (
    SELECT 
        vt.Name AS VoteTypeName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        vt.Name
)

SELECT 
    pd.PostTypeName,
    pd.PostCount,
    pd.AvgScore,
    pd.UserCount,
    vd.VoteTypeName,
    vd.VoteCount
FROM 
    PostDetails pd
CROSS JOIN 
    VoteDetails vd
ORDER BY 
    pd.PostTypeName, vd.VoteTypeName;