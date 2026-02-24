WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
        JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name IN ('Post Closed', 'Post Reopened', 'Post Deleted', 'Post Undeleted')
),
UserVotes AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
        LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(uc.Upvotes, 0) - COALESCE(uc.Downvotes, 0) AS NetVotes,
        ph.CreationDate AS LastHistoryDate,
        ROW_NUMBER() OVER (ORDER BY COALESCE(uc.Upvotes, 0) - COALESCE(uc.Downvotes, 0) DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN UserVotes uc ON p.OwnerUserId = uc.UserId
        LEFT JOIN RecursivePostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) > 5
    GROUP BY 
        p.Id, p.Title, ph.CreationDate, uc.Upvotes, uc.Downvotes
),
FinalMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.NetVotes,
        tp.LastHistoryDate,
        CASE 
            WHEN tp.LastHistoryDate IS NULL THEN 'Never changed'
            WHEN tp.LastHistoryDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Recently Active'
            ELSE 'Old Activity'
        END AS ActivityStatus
    FROM 
        TopPosts tp
    WHERE 
        tp.Rank <= 10
)
SELECT 
    fm.PostId,
    fm.Title,
    fm.NetVotes,
    fm.ActivityStatus,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    FinalMetrics fm
    LEFT JOIN Votes v ON fm.PostId = v.PostId AND v.VoteTypeId IN (8, 9) 
GROUP BY 
    fm.PostId, fm.Title, fm.NetVotes, fm.ActivityStatus
ORDER BY 
    fm.NetVotes DESC, fm.ActivityStatus;