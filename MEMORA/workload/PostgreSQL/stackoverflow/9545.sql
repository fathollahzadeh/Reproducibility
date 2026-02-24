
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COALESCE(BR.BadgeCount, 0) AS BronzeCount,
        COALESCE(SR.BadgeCount, 0) AS SilverCount,
        COALESCE(GR.BadgeCount, 0) AS GoldCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS RankPosition
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        WHERE 
            Class = 3 
        GROUP BY 
            UserId
    ) BR ON p.OwnerUserId = BR.UserId
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        WHERE 
            Class = 2 
        GROUP BY 
            UserId
    ) SR ON p.OwnerUserId = SR.UserId
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        WHERE 
            Class = 1 
        GROUP BY 
            UserId
    ) GR ON p.OwnerUserId = GR.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.BronzeCount,
    rp.SilverCount,
    rp.GoldCount,
    rp.RankPosition
FROM 
    RankedPosts rp
WHERE 
    rp.RankPosition <= 100
ORDER BY 
    rp.RankPosition;
