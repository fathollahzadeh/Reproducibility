WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(UP.PercentageUpVotes, 0) AS PercentageUpVotes,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN pt.Name = 'Question' THEN 'Question' ELSE 'Other' END 
                             ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            (SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(VoteTypeId), 0)) AS PercentageUpVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) UP ON p.Id = UP.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

TagsWithCounts AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),

PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        STRING_AGG(CASE 
                WHEN ph.Comment IS NOT NULL THEN 'Comment: ' || ph.Comment 
                ELSE 'No Comment' 
            END, '; ') AS HistoryComments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate
),

QuestionAnswerStats AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswersCount,
        COALESCE(SUM(CASE WHEN a.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AnsweredByUsersCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.PercentageUpVotes,
    tc.PostCount AS TagPostCount,
    COALESCE(qas.AnswersCount, 0) AS AnswersCount,
    COALESCE(qas.AnsweredByUsersCount, 0) AS AnsweredByUsersCount,
    ph.HistoryComments
FROM 
    RankedPosts rp
LEFT JOIN 
    TagsWithCounts tc ON rp.Title LIKE '%' || tc.TagName || '%'
LEFT JOIN 
    QuestionAnswerStats qas ON rp.PostId = qas.QuestionId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC,
    rp.CreationDate DESC;