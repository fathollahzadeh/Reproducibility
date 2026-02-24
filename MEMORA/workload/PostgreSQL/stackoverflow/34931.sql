WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
TopUserPosts AS (
    SELECT 
        up.PostId,
        up.Title,
        ur.DisplayName AS OwnerDisplayName,
        ur.Reputation,
        up.CommentCount,
        up.CreationDate,
        up.Score
    FROM 
        RankedPosts up
    JOIN 
        UserReputation ur ON up.OwnerUserId = ur.UserId
    WHERE 
        ur.ReputationRank <= 10  
)
SELECT 
    tup.OwnerDisplayName,
    COUNT(tup.PostId) AS NumberOfPosts,
    AVG(tup.Score) AS AverageScore,
    SUM(tup.CommentCount) AS TotalComments,
    MAX(tup.CreationDate) AS MostRecentPost
FROM 
    TopUserPosts tup
GROUP BY 
    tup.OwnerDisplayName
ORDER BY 
    NumberOfPosts DESC
LIMIT 5;