WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        u.Views,
        (u.UpVotes - u.DownVotes) AS NetVotes,
        CASE 
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS UserLevel
    FROM Users u
),

PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        t.TagName,
        p.OwnerUserId,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM Posts p
    JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE p.PostTypeId = 1 
)

SELECT 
    u.DisplayName AS UserName,
    u.UserLevel,
    COUNT(DISTINCT pp.PostId) AS TotalPosts,
    SUM(pp.Score) AS TotalScore,
    SUM(pp.ViewCount) AS TotalViews,
    AVG(pp.CommentCount) AS AvgComments,
    STRING_AGG(DISTINCT pp.TagName, ', ') AS AssociatedTags
FROM UserScores u
JOIN PopularPosts pp ON u.UserId = pp.OwnerUserId
GROUP BY u.UserId, u.DisplayName, u.UserLevel
ORDER BY TotalScore DESC, TotalViews DESC
LIMIT 10;