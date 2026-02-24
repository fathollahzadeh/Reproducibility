WITH RankedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  
        AND u.Reputation >= 1000  
),
CommentStatistics AS (
    SELECT 
        PostId,
        AVG(Score) AS AvgCommentScore,
        MAX(CreationDate) AS LatestCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
),
CloseReasonCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        PostId
),
RecentActivities AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastActivityDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 24) AS EditCount
    FROM 
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '365 days'
    GROUP BY 
        p.Id
),
FinalSelection AS (
    SELECT 
        q.QuestionId,
        q.Title,
        q.Score,
        q.CreationDate,
        q.RankScore,
        cs.AvgCommentScore,
        cs.LatestCommentDate,
        rc.CloseCount,
        rc.ReopenCount,
        ra.LastActivityDate,
        ra.EditCount
    FROM 
        RankedQuestions q
    LEFT JOIN CommentStatistics cs ON cs.PostId = q.QuestionId
    LEFT JOIN CloseReasonCounts rc ON rc.PostId = q.QuestionId
    LEFT JOIN RecentActivities ra ON ra.PostId = q.QuestionId
    WHERE 
        q.RankScore <= 5  
)
SELECT 
    fs.QuestionId,
    fs.Title,
    fs.Score,
    fs.CreationDate,
    fs.AvgCommentScore,
    fs.LatestCommentDate,
    fs.CloseCount,
    fs.ReopenCount,
    fs.LastActivityDate,
    fs.EditCount,
    COALESCE(d.DOWN, 0) AS DownVoteCount
FROM 
    FinalSelection fs
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS DOWN
    FROM 
        Votes
    WHERE 
        VoteTypeId = 3  
    GROUP BY 
        PostId
) d ON d.PostId = fs.QuestionId
ORDER BY 
    fs.Score DESC, 
    fs.CreationDate ASC
LIMIT 10;