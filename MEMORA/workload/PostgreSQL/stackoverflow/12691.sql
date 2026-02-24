
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum <= 100 
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VotesCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    ue.UserId,
    ue.DisplayName,
    ue.VotesCount,
    ue.AverageBounty
FROM 
    TopPosts tp
JOIN 
    UserEngagement ue ON tp.PostId = (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = ue.UserId
        ORDER BY 
            p.CreationDate DESC 
        LIMIT 1
    )
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
