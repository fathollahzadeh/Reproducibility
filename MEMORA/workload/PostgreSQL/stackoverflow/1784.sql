
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(a.Score, 0) AS AcceptedAnswerScore,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, a.Score
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        AcceptedAnswerScore,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RowNum = 1
)

SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    CASE 
        WHEN trp.AcceptedAnswerScore > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer,
    CASE 
        WHEN trp.CommentCount > 5 THEN 'High Activity'
        WHEN trp.CommentCount BETWEEN 1 AND 5 THEN 'Moderate Activity'
        ELSE 'No Activity'
    END AS ActivityLevel,
    COALESCE((
        SELECT 
            STRING_AGG(b.Name, ', ') 
        FROM 
            Badges b 
        WHERE 
            b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId)
    ), 'No Badges') AS UserBadges
FROM 
    TopRankedPosts trp
WHERE 
    trp.ViewCount > 100
ORDER BY 
    trp.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
