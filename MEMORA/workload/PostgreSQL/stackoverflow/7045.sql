
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        DATE_TRUNC('day', p.CreationDate) AS PostDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
      AND 
        p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        AnswerCount,
        OwnerDisplayName,
        PostDate,
        rn
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        AVG(p.Score) AS AvgScore,
        MAX(p.ViewCount) AS MaxViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.OwnerDisplayName,
    us.DisplayName AS UserDisplayName,
    us.QuestionsAsked,
    us.AnswersGiven,
    us.AvgScore,
    us.MaxViewCount
FROM 
    TopPosts tp
JOIN 
    UserStats us ON tp.OwnerDisplayName = us.DisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 50;
