WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 13 THEN 1 END) AS UndeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CombinedStats AS (
    SELECT 
        rp.PostId,
        rp.OwnerUserId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ups.TotalVotes AS UserTotalVotes,
        ups.Upvotes AS UserUpvotes,
        ups.Downvotes AS UserDownvotes,
        phs.CloseReopenCount,
        phs.DeleteCount,
        phs.UndeleteCount
    FROM 
        RankedPosts rp
    JOIN 
        UserVoteStats ups ON rp.OwnerUserId = ups.UserId
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
)

SELECT 
    cs.PostId,
    cs.OwnerUserId,
    cs.Title,
    cs.CreationDate,
    cs.ViewCount,
    COALESCE(cs.UserTotalVotes, 0) AS UserTotalVotes,
    COALESCE(cs.UserUpvotes, 0) AS UserUpvotes,
    COALESCE(cs.UserDownvotes, 0) AS UserDownvotes,
    COALESCE(cs.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(cs.DeleteCount, 0) AS DeleteCount,
    COALESCE(cs.UndeleteCount, 0) AS UndeleteCount,
    CASE 
        WHEN cs.Score > 0 THEN 'Positive' 
        WHEN cs.Score < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS ScoreType,
    CASE 
        WHEN cs.CloseReopenCount > 0 THEN 'Has been closed/reopened'
        ELSE 'Not closed/reopened'
    END AS ClosureStatus
FROM 
    CombinedStats cs
WHERE 
    cs.UserTotalVotes IS NOT NULL
    AND cs.ViewCount > 0
ORDER BY 
    cs.ViewCount DESC, 
    cs.Score DESC;