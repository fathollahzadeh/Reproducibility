
WITH UserPosts AS (
    SELECT 
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId, p.PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank,
        CASE 
            WHEN u.Reputation < 1000 THEN 'Newbie'
            WHEN u.Reputation < 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS UserLevel
    FROM 
        Users u
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(ph.CreationDate, p.CreationDate) AS LastEditDate,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
)
SELECT 
    up.OwnerUserId AS UserId,
    ur.Reputation,
    ur.UserLevel,
    SUM(up.TotalPosts) AS TotalPosts,
    SUM(up.PositivePosts) AS TotalPositivePosts,
    SUM(up.NegativePosts) AS TotalNegativePosts,
    STRING_AGG(CONCAT(pd.Title, ' (', pd.PostType, ')'), '; ') AS PostTitles,
    AVG(COALESCE(pd.CommentCount, 0)) AS AverageCommentsPerPost,
    COUNT(DISTINCT pd.PostId) AS UniquePostCount
FROM 
    UserPosts up
JOIN 
    UserReputation ur ON up.OwnerUserId = ur.UserId
LEFT JOIN 
    PostDetails pd ON up.OwnerUserId = pd.OwnerUserId
GROUP BY 
    up.OwnerUserId, ur.Reputation, ur.UserLevel
HAVING 
    COUNT(DISTINCT pd.PostId) > 0
ORDER BY 
    ur.Reputation DESC;
