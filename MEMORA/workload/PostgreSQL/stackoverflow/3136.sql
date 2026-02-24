
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
), UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), PostsWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.UpVotes,
        us.DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        Badges b ON us.UserId = b.UserId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, us.UserId, us.DisplayName, us.Reputation, us.UpVotes, us.DownVotes
), FinalResults AS (
    SELECT 
        p.Title,
        p.CreationDate,
        p.UpVotes,
        p.DownVotes,
        p.BadgeCount,
        CASE 
            WHEN p.BadgeCount = 0 THEN 'No Badges'
            WHEN p.BadgeCount < 3 THEN 'Few Badges'
            ELSE 'Many Badges'
        END AS BadgeCategory
    FROM 
        PostsWithBadges p
    WHERE 
        p.UpVotes - p.DownVotes > 10
)
SELECT 
    fr.Title,
    fr.CreationDate,
    fr.UpVotes,
    fr.DownVotes,
    fr.BadgeCategory
FROM 
    FinalResults fr
ORDER BY 
    fr.UpVotes DESC, fr.CreationDate DESC
LIMIT 10;
