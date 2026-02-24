
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,  
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes   
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS RevisionCount,
        MAX(ph.CreationDate) AS LastRevisionDate,
        STRING_AGG(DISTINCT CASE WHEN pht.Name IS NOT NULL THEN pht.Name END, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),

ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS ActivePostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        (TIMESTAMP '2024-10-01 12:34:56' - MAX(c.CreationDate)) AS DaysSinceLastComment
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score AS PostScore,
    rp.ViewCount,
    rp.AnswerCount,
    ph.RevisionCount,
    ph.LastRevisionDate,
    ph.ChangeTypes,
    au.UserId,
    au.DisplayName,
    au.Reputation,
    au.ActivePostsCount,
    ra.CommentCount,
    ra.DaysSinceLastComment,
    CASE 
        WHEN ra.DaysSinceLastComment IS NULL THEN 'No Comments Yet' 
        WHEN ra.DaysSinceLastComment < INTERVAL '30 days' THEN 'Recently Active'
        ELSE 'Stale Post'
    END AS ActivityStatus,
    CASE 
        WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
        WHEN rp.UpVotes < rp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
JOIN 
    ActiveUsers au ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = au.UserId)
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.rn = 1  
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 100;
