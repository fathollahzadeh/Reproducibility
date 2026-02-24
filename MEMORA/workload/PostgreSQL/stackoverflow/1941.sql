
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostWithBadges AS (
    SELECT 
        rp.Title,
        rp.OwnerDisplayName,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        (rp.UpVotes - rp.DownVotes) AS Score,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.Id)
    WHERE 
        rp.rn = 1
)
SELECT 
    Title,
    OwnerDisplayName,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Score,
    CommentCount,
    AnswerCount
FROM 
    PostWithBadges
WHERE 
    (GoldBadges + SilverBadges + BronzeBadges) > 0
ORDER BY 
    Score DESC, CommentCount DESC
LIMIT 10;
