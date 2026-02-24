
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    GROUP BY 
        u.Id, u.DisplayName
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        u.UserId,
        u.DisplayName,
        u.TotalPosts,
        u.TotalUpvotes
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers u ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.UserId)
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tpd.Title,
    tpd.ViewCount,
    tpd.Score,
    tpd.AnswerCount,
    tpd.DisplayName AS OwnerName,
    tpd.TotalPosts,
    tpd.TotalUpvotes
FROM 
    TopPostDetails tpd
ORDER BY 
    tpd.Score DESC, tpd.ViewCount DESC;
