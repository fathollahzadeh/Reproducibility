
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
LatestPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
),
PostStats AS (
    SELECT 
        lp.PostId,
        lp.OwnerUserId,
        lp.Title,
        lp.CreationDate,
        COUNT(DISTINCT p2.Id) AS TotalAnswers,
        COUNT(DISTINCT ph.Id) AS HistoryEdits,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastCloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS LastDeleteDate
    FROM 
        LatestPosts lp
    LEFT JOIN 
        Posts p2 ON lp.PostId = p2.ParentId
    LEFT JOIN 
        PostHistory ph ON lp.PostId = ph.PostId
    WHERE 
        lp.PostRank = 1
    GROUP BY 
        lp.PostId, lp.OwnerUserId, lp.Title, lp.CreationDate
),
FinalStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        COALESCE(SUM(ps.TotalAnswers), 0) AS TotalPostAnswers,
        COALESCE(SUM(ps.HistoryEdits), 0) AS TotalHistoryEdits,
        COALESCE(MIN(ps.LastCloseDate), '1970-01-01') AS FirstCloseDate,
        COUNT(DISTINCT ps.PostId) AS PostsParticipated,
        COUNT(DISTINCT CASE WHEN ps.LastDeleteDate IS NOT NULL THEN ps.PostId END) AS DeletedPosts
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostStats ps ON ua.UserId = ps.OwnerUserId
    WHERE 
        ua.Reputation > 100 AND 
        (ua.PostCount > 2 OR ua.CommentCount > 5)
    GROUP BY 
        ua.UserId, ua.DisplayName, ua.Reputation
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.Reputation,
    f.TotalPostAnswers,
    f.TotalHistoryEdits,
    f.FirstCloseDate,
    CASE 
        WHEN f.DeletedPosts > 0 THEN 'Active' 
        ELSE 'Inactive' 
    END AS UserStatus
FROM 
    FinalStats f
ORDER BY 
    f.Reputation DESC,
    f.TotalPostAnswers DESC
LIMIT 10;
