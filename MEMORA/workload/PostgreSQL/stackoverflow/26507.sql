
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount, p.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.AnswerCount,
        CASE 
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS HasAcceptedAnswer
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5  
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AverageViews,
        SUM(CASE WHEN HasAcceptedAnswer = 'Yes' THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        FilteredPosts
    GROUP BY 
        unnest(string_to_array(Tags, '>'))
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AverageViews,
    ts.AcceptedAnswers,
    p.Name AS PostHistoryTypeName
FROM 
    TagStatistics ts
JOIN 
    PostHistoryTypes p ON ts.PostCount > 1 AND ts.AverageViews > 50  
ORDER BY 
    ts.AverageViews DESC, ts.PostCount DESC;
