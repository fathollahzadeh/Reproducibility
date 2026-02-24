WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenedCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(DISTINCT c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
TopRankedPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.CommentCount IS NULL THEN 'No Comments' 
            ELSE 'Has Comments' 
        END AS CommentStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
AnswerDetails AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        MAX(a.CreationDate) AS MostRecentAnswerDate
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    GROUP BY 
        p.Id
),
QuestionsWithAnswerDetails AS (
    SELECT 
        trp.Title,
        trp.CreationDate,
        trp.CommentCount,
        trp.CloseReopenedCount,
        trp.UpVotes,
        trp.DownVotes,
        TRIM(trp.CommentStatus) AS CommentStatus,
        COALESCE(ad.AnswerCount, 0) AS AnswerCount,
        ad.MostRecentAnswerDate
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        AnswerDetails ad ON trp.PostId = ad.QuestionId
)
SELECT 
    *,
    CASE 
        WHEN AnswerCount = 0 THEN 'No Answers Yet'
        WHEN MostRecentAnswerDate IS NULL THEN 'Answer Not Found'
        ELSE 'Answers Available'
    END AS AnswerStatus,
    CASE 
        WHEN CloseReopenedCount > 0 THEN 'Reopened Post'
        ELSE 'Post Status Normal'
    END AS PostStatus,
    ARRAY_TO_STRING(STRING_TO_ARRAY(Tags, ','), ', ') AS FormattedTags
FROM 
    QuestionsWithAnswerDetails
LEFT JOIN (
    SELECT 
        p.Id AS PostId,
        p.Tags
    FROM 
        Posts p
) sub ON QuestionsWithAnswerDetails.Title = sub.PostId::varchar
ORDER BY 
    CloseReopenedCount DESC, 
    UpVotes DESC 
LIMIT 10;