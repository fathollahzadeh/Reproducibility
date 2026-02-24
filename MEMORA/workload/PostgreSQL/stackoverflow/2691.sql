WITH RankedQuestions AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score
),
RecentVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostStats AS (
    SELECT 
        rq.Id,
        rq.Title,
        rq.CreationDate,
        rq.Score,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        rq.AnswerCount,
        CASE 
            WHEN rq.Score >= 0 THEN 'Positive'
            ELSE 'Negative'
        END AS ScoreType
    FROM 
        RankedQuestions rq
    LEFT JOIN 
        RecentVotes rv ON rq.Id = rv.PostId
)
SELECT 
    ps.*,
    CASE 
        WHEN ps.ScoreType = 'Positive' THEN 'This question is well-received.'
        WHEN ps.ScoreType = 'Negative' THEN 'This question could use improvement.'
        ELSE 'No votes yet.'
    END AS Feedback
FROM 
    PostStats ps
WHERE 
    ps.AnswerCount > 5
ORDER BY 
    ps.CreationDate DESC
LIMIT 10;
