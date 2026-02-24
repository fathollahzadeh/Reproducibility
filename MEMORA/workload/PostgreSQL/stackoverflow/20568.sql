WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId
),
FinalSelection AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        CASE 
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Pending' 
        END AS AnswerStatus
    FROM 
        PostStatistics ps
    JOIN 
        RankedPosts rp ON ps.PostId = rp.PostId
    WHERE 
        ps.UpVoteCount > ps.DownVoteCount
        AND rp.PostRank <= 10
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.CreationDate,
    fs.Score,
    fs.CommentCount,
    fs.UpVoteCount,
    fs.DownVoteCount,
    fs.AnswerStatus,
    CASE 
        WHEN fs.CommentCount > 0 THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS CommentStatus,
    (SELECT 
        COUNT(DISTINCT ph.Id)
     FROM 
        PostHistory ph
     WHERE 
        ph.PostId = fs.PostId
        AND ph.PostHistoryTypeId IN (10, 11, 12) 
        AND ph.CreationDate > DATE_TRUNC('year', cast('2024-10-01 12:34:56' as timestamp))) AS CloseReopenedCount
FROM 
    FinalSelection fs
ORDER BY 
    fs.Score DESC, 
    fs.CommentCount DESC
LIMIT 25;