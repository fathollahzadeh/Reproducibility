
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
EligiblePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.PostRank,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(pt.Name, 'N/A') AS PostTypeName,
        rp.AverageScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostTypes pt ON EXISTS (
            SELECT 1 
            FROM Posts p 
            WHERE p.Id = rp.PostId AND p.PostTypeId = pt.Id
        )
    WHERE 
        rp.CommentCount > 5
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.PostRank, u.DisplayName, pt.Name, rp.AverageScore
),
FinalSelection AS (
    SELECT 
        ep.PostId,
        ep.Title,
        ep.CreationDate,
        ep.ViewCount,
        ep.OwnerDisplayName,
        ep.TotalBadges,
        ep.PostTypeName,
        ep.AverageScore,
        RANK() OVER (ORDER BY ep.TotalBadges DESC, ep.ViewCount DESC) AS BadgeRank
    FROM 
        EligiblePosts ep
    WHERE 
        ep.PostRank = 1
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.CreationDate,
    fs.ViewCount,
    fs.OwnerDisplayName,
    fs.TotalBadges,
    fs.PostTypeName,
    CASE 
        WHEN fs.AverageScore IS NULL THEN 'No votes'
        WHEN fs.AverageScore > 0 THEN 'Positive'
        WHEN fs.AverageScore < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    FinalSelection fs
WHERE 
    fs.BadgeRank <= 10
ORDER BY 
    fs.BadgeRank, fs.ViewCount DESC;
