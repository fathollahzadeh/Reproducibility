
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.PostTypeId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.PostId) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MIN(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ra.DisplayName AS OwnerDisplayName,
        ua.UserId,
        ua.CommentCount,
        ua.UpVotes,
        ua.DownVotes,
        pHd.ClosedDate,
        pHd.ReopenedDate,
        CASE 
            WHEN pHd.ClosedDate IS NOT NULL THEN 
                CASE 
                    WHEN pHd.ReopenedDate IS NOT NULL THEN 'Reopened'
                    ELSE 'Closed'
                END
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    JOIN 
        Users ra ON rp.OwnerUserId = ra.Id
    JOIN 
        UserActivity ua ON ua.UserId = ra.Id
    LEFT JOIN 
        PostHistoryDetails pHd ON rp.PostId = pHd.PostId
    WHERE 
        rp.ScoreRank <= 5
)

SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    CommentCount,
    UpVotes,
    DownVotes,
    PostStatus,
    CASE 
        WHEN PostStatus = 'Closed' THEN 'This post is closed.'
        WHEN PostStatus = 'Reopened' THEN 'This post is reopened.'
        ELSE 'This post is active.'
    END AS PostMessage
FROM 
    FinalResults
ORDER BY 
    UpVotes DESC, 
    CommentCount DESC;
