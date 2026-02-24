
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(ph.UserId, -1) AS LastModifiedBy,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(CreationDate)
            FROM PostHistory
            WHERE PostId = p.Id
        )
)
SELECT 
    u.DisplayName,
    MAX(pa.Title) AS LatestPost,
    SUM(pa.ViewCount) AS TotalViews,
    AVG(pa.Score) AS AverageScore,
    MAX(ua.Reputation) AS MaxReputation,
    CASE 
        WHEN MAX(pa.ViewCount) IS NULL THEN 'No Views'
        ELSE 'Has Views'
    END AS PostViewStatus
FROM 
    UserActivity ua
JOIN 
    PostDetails pa ON ua.UserId = pa.LastModifiedBy
JOIN 
    Users u ON ua.UserId = u.Id
WHERE 
    ua.Reputation > 1000
    AND pa.UserPostRank <= 5
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(pa.PostId) > 0
ORDER BY 
    MaxReputation DESC;
