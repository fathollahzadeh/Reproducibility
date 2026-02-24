
WITH RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY COUNT(*) DESC) AS VoteRank
    FROM Votes v
    WHERE v.VoteTypeId IN (2, 3)  
    GROUP BY v.PostId, v.VoteTypeId
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        COALESCE(ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '><'), 1), 0) AS TagCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.AcceptedAnswerId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes c ON c.Id = CAST(ph.Comment AS INTEGER)
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId, ph.CreationDate
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.ViewCount,
    ps.CreationDate,
    ps.TagCount,
    COALESCE(cr.CloseReasons, 'No close reasons') AS CloseReasons,
    RANK() OVER (ORDER BY (ps.UpvoteCount - ps.DownvoteCount) DESC, ps.CreationDate DESC) AS PopularityRank,
    CASE 
        WHEN ps.AcceptedAnswerId IS NOT NULL 
            THEN (SELECT p2.Title FROM Posts p2 WHERE p2.Id = ps.AcceptedAnswerId)
        ELSE 'No accepted answer' 
    END AS AcceptedAnswerTitle
FROM PostStats ps
LEFT JOIN ClosedPosts cr ON ps.PostId = cr.PostId
WHERE ps.RecentPostRank <= 100  
ORDER BY ps.ViewCount DESC, ps.UpvoteCount DESC;
