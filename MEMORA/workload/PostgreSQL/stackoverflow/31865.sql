
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
PostInteractionCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS TotalComments,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS HasUpvote,
        MAX(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS HasDownvote
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPostStats AS (
    SELECT 
        p.Id AS ClosedPostId,
        COUNT(ph.Id) AS CloseVoteCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        p.Id
),
FinalStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        pi.TotalComments,
        pi.HasUpvote,
        pi.HasDownvote,
        cps.CloseVoteCount,
        cps.LastClosedDate,
        CASE 
            WHEN cps.CloseVoteCount > 0 THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostInteractionCounts pi ON rp.PostId = pi.PostId
    LEFT JOIN 
        ClosedPostStats cps ON rp.PostId = cps.ClosedPostId
)
SELECT 
    fs.*,
    CASE 
        WHEN fs.Score >= 10 AND fs.UpVotes > fs.DownVotes THEN 'Highly Engaged'
        WHEN fs.Score < 10 AND fs.TotalComments > 5 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    FinalStats fs
ORDER BY 
    fs.ViewCount DESC, fs.CreationDate DESC;
