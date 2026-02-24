WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Answered'
            ELSE 'Unanswered'
        END AS AnswerStatus
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId
),
PostVotes AS (
    SELECT 
        pv.PostId,
        SUM(CASE WHEN pv.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedVotes,
        SUM(CASE WHEN pv.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN pv.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes pv
    GROUP BY 
        pv.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseEvents,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankByScore,
    COALESCE(cv.CloseEvents, 0) AS CloseCount,
    cv.LastClosedDate,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.AnswerStatus,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score Recorded'
        WHEN rp.Score > 10 THEN 'Highly Valued'
        ELSE 'Needs Attention'
    END AS ValueAssessment
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cv ON rp.PostId = cv.PostId
WHERE 
    rp.RankByScore <= 5 
ORDER BY 
    rp.RankByScore, rp.Score DESC;