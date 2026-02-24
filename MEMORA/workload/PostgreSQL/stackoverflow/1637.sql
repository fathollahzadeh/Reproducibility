
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
),
AnsweredPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ap.AnswerCount,
        CASE 
            WHEN ap.AnswerCount > 5 THEN 'High Engagement'
            WHEN ap.AnswerCount BETWEEN 1 AND 5 THEN 'Moderate Engagement'
            ELSE 'Low Engagement' 
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    JOIN 
        AnsweredPosts ap ON rp.PostId = ap.PostId
    WHERE 
        rp.UserRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.EngagementLevel,
    COALESCE((
        SELECT 
            STRING_AGG(c.Text, ' | ')
        FROM 
            Comments c
        WHERE 
            c.PostId = tp.PostId
    ), 'No Comments') AS Comments
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
