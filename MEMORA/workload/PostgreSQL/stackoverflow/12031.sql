
WITH PostTypeCount AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

UserCountByYear AS (
    SELECT 
        DATE_TRUNC('year', CreationDate) AS RegistrationYear,
        COUNT(Id) AS TotalUsers
    FROM 
        Users
    GROUP BY 
        DATE_TRUNC('year', CreationDate)
),

VoteTypeCount AS (
    SELECT 
        vt.Name AS VoteType,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        vt.Name
)

SELECT 
    'PostTypeCount' AS BenchmarkType,
    PostType,
    TotalPosts
FROM 
    PostTypeCount

UNION ALL

SELECT 
    'UserCountByYear' AS BenchmarkType,
    CAST(RegistrationYear AS VARCHAR) AS RegistrationYear,
    TotalUsers
FROM 
    UserCountByYear

UNION ALL

SELECT 
    'VoteTypeCount' AS BenchmarkType,
    VoteType,
    TotalVotes
FROM 
    VoteTypeCount;
