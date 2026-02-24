
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
        AND p.PostTypeId = 1
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        COALESCE(ua.CommentCount, 0) AS Comments,
        COALESCE(ua.UpVoteCount, 0) AS UpVotes,
        COALESCE(ua.DownVoteCount, 0) AS DownVotes,
        COALESCE(ua.GoldBadges, 0) AS GoldBadges,
        RANK() OVER (ORDER BY COALESCE(ua.CommentCount, 0) + COALESCE(ua.UpVoteCount, 0) - COALESCE(ua.DownVoteCount, 0) DESC) AS UserRank
    FROM 
        UserActivity ua
),
PostWithBestUser AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        tu.DisplayName AS BestUser,
        tu.UserRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tu ON rp.PostId = (
            SELECT 
                p.Id
            FROM 
                Posts p
            WHERE 
                p.OwnerUserId IS NOT NULL
                AND p.AnswerCount > 0
                AND p.AcceptedAnswerId IS NOT NULL
            ORDER BY 
                p.Score DESC
            LIMIT 1
        )
    WHERE 
        rp.rn = 1
)
SELECT 
    p.*,
    COALESCE(pw.BestUser, 'No authors') AS BestUser
FROM 
    RankedPosts p
FULL OUTER JOIN 
    PostWithBestUser pw ON p.PostId = pw.PostId
WHERE 
    p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
ORDER BY 
    p.CreationDate DESC;
