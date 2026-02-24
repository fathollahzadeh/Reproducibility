
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                              WHEN p.PostTypeId = 1 THEN 'Question'
                                              WHEN p.PostTypeId = 2 THEN 'Answer'
                                              ELSE 'Other'
                                          END ORDER BY p.Score DESC) AS Rank,
        CARDINALITY(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  
),
PopularQuestions AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        Score,
        ViewCount,
        TagCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 AND TagCount > 2  
),
TopAnswersByQuestion AS (
    SELECT 
        p.Id AS QuestionId,
        pa.Id AS AnswerId,
        pa.OwnerUserId,
        pu.DisplayName AS AnswerOwner,
        pa.CreationDate AS AnswerDate,
        pa.Score AS AnswerScore
    FROM 
        Posts pa
    JOIN 
        Posts p ON pa.ParentId = p.Id
    JOIN 
        Users pu ON pa.OwnerUserId = pu.Id
    WHERE 
        pa.PostTypeId = 2  
        AND p.PostTypeId = 1  
)
SELECT 
    pq.PostId AS QuestionId,
    pq.Title AS QuestionTitle,
    pq.OwnerDisplayName AS QuestionOwner,
    pq.CreationDate AS QuestionDate,
    COUNT(ta.AnswerId) AS AnswerCount,
    COALESCE(MAX(ta.AnswerScore), 0) AS HighestAnswerScore,
    AVG(ta.AnswerScore) AS AvgAnswerScore
FROM 
    PopularQuestions pq
LEFT JOIN 
    TopAnswersByQuestion ta ON pq.PostId = ta.QuestionId
GROUP BY 
    pq.PostId, pq.Title, pq.OwnerDisplayName, pq.CreationDate, pq.Score
ORDER BY 
    pq.Score DESC;
