
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS TotalComments,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.Score
),

CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS int) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 500 
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.TotalComments,
    rp.Tags,
    cr.CloseReasons,
    ur.DisplayName AS MostActiveUser,
    ur.Reputation AS UserReputation
FROM 
    RankedPosts rp
JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
JOIN 
    (
        SELECT 
            p.OwnerUserId,
            COUNT(*) AS PostCount
        FROM 
            Posts p
        WHERE 
            p.PostTypeId = 1 
        GROUP BY 
            p.OwnerUserId
        ORDER BY 
            PostCount DESC
        LIMIT 1
    ) AS ActiveUser ON ActiveUser.OwnerUserId = cr.PostId
JOIN 
    UserReputation ur ON ur.UserId = ActiveUser.OwnerUserId
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Rank;
