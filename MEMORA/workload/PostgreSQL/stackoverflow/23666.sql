WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
),

AggregatedPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        COALESCE(cp.HistoryType, 'No History') AS ClosureStatus,
        DENSE_RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS ScoreViewRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId AND cp.HistoryRank = 1
)

SELECT 
    aps.PostId,
    aps.Title,
    aps.CreationDate,
    aps.Score,
    aps.ViewCount,
    aps.CommentCount,
    aps.UpVoteCount,
    aps.DownVoteCount,
    aps.ClosureStatus,
    CASE 
        WHEN aps.ClosureStatus = 'Post Closed' THEN 'Closed'
        WHEN aps.ClosureStatus = 'Post Reopened' THEN 'Reopened'
        ELSE 'Active'
    END AS Status,
    (aps.UpVoteCount - aps.DownVoteCount) AS NetVotes,
    NULLIF(aps.CommentCount, 0) AS NonZeroComments,
    CASE 
        WHEN aps.Score IS NULL THEN 'No Score'
        ELSE 'Scored'
    END AS ScorePresence,
    CONCAT('Title: ', aps.Title, ' | Status: ', 
        CASE 
            WHEN aps.ClosureStatus = 'No History' THEN 'Active'
            ELSE aps.ClosureStatus 
        END) AS DisplayInfo
FROM 
    AggregatedPostStats aps
WHERE 
    aps.ScoreViewRank <= 10 
    OR aps.ClosureStatus != 'No History'
ORDER BY 
    aps.Score DESC, aps.ViewCount DESC;