WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(u.Reputation, 0) AS UserReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        RANK() OVER (ORDER BY COALESCE(p.Score, 0) DESC, p.CreationDate ASC) AS ScoreRank,
        SUBSTRING(p.Body, 1, 100) AS ShortBody
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        AnswerCount,
        UserReputation,
        rn,
        ScoreRank,
        ShortBody
    FROM 
        RankedPosts
    WHERE 
        rn = 1 AND ScoreRank <= 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT('Type: ', pht.Name, ' by: ', ph.UserDisplayName, ' on: ', ph.CreationDate), '; ') AS HistoryInfo,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
CommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        AVG(LENGTH(Text)) AS AverageCommentLength
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalReport AS (
    SELECT 
        t.PostId,
        t.Title,
        t.ViewCount,
        t.AnswerCount,
        t.UserReputation,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(c.AverageCommentLength, 0) AS AverageCommentLength,
        COALESCE(h.HistoryCount, 0) AS HistoryCount,
        h.HistoryInfo
    FROM 
        TopPosts t
    LEFT JOIN 
        CommentStats c ON t.PostId = c.PostId
    LEFT JOIN 
        PostHistoryDetails h ON t.PostId = h.PostId
)
SELECT 
    PostId,
    Title,
    ViewCount,
    AnswerCount,
    UserReputation,
    CommentCount,
    AverageCommentLength,
    HistoryCount,
    HistoryInfo
FROM 
    FinalReport
WHERE 
    ViewCount > 10
ORDER BY 
    AnswerCount DESC, ViewCount DESC
LIMIT 50;