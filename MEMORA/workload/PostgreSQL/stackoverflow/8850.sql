WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        rp.*,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        us.QuestionCount,
        us.AnswerCount
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.PostId = us.UserId
    WHERE 
        rp.PostRank <= 5 
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.CommentCount,
    pp.VoteCount,
    pp.DisplayName,
    pp.Reputation,
    pp.BadgeCount,
    pp.QuestionCount,
    pp.AnswerCount
FROM 
    PopularPosts pp
ORDER BY 
    pp.Score DESC, 
    pp.ViewCount DESC;