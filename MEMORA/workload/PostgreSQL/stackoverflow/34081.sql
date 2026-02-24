
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
),
GroupedPostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        MAX(ph.CreationDate) AS LastActionDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY MAX(ph.CreationDate) DESC) AS LastActionRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedPosts,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenedPosts
    FROM 
        Users u
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)
SELECT 
    gcd.Id AS PostId,
    gcd.Title AS PostTitle,
    gcd.CommentCount,
    gcd.UpVotes,
    gcd.DownVotes,
    gcd.LastActionDate,
    u.DisplayName AS LastUserActioned,
    u.Reputation AS LastUserReputation,
    u.ClosedPosts,
    u.ReopenedPosts
FROM 
    GroupedPostDetails gcd
LEFT JOIN 
    ActiveUsers u ON gcd.LastActionRank = 1 AND u.Id = (SELECT UserId FROM PostHistory WHERE PostId = gcd.Id ORDER BY CreationDate DESC LIMIT 1)
WHERE 
    gcd.CommentCount > 10
ORDER BY 
    gcd.LastActionDate DESC;
