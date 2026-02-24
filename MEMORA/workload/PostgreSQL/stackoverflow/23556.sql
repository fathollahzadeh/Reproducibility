
WITH RecursivePostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        (SELECT COUNT(*)
         FROM PostHistory ph
         WHERE ph.PostId = p.Id 
         AND ph.PostHistoryTypeId IN (1, 4)
        ) AS TitleEditCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months' AND TIMESTAMP '2024-10-01 12:34:56'
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    pa.UserId,
    pa.DisplayName,
    pa.UpVoteCount - pa.DownVoteCount AS NetVoteCount,
    RPD.Title AS RecentPostTitle,
    RPD.ViewCount,
    RPD.UserPostRank,
    PI.CommentCount AS PostCommentCount,
    PI.UpVoteCount AS PostUpVoteCount,
    PI.DownVoteCount AS PostDownVoteCount,
    PI.TitleEditCount
FROM 
    UserActivity pa
JOIN 
    RecursivePostDetails RPD ON pa.UserId = RPD.OwnerUserId
LEFT JOIN 
    PostInteraction PI ON PI.PostId = RPD.AcceptedAnswerId
WHERE 
    (pa.UpVoteCount > pa.DownVoteCount AND pa.CommentCount > 10)
    OR pa.GoldBadgeCount > 0
    OR (RPD.UserPostRank = 1 AND RPD.Score > 10)
ORDER BY 
    NetVoteCount DESC NULLS LAST,
    RPD.CreationDate DESC;
