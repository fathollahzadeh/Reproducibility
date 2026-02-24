
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        CASE 
            WHEN COUNT(b.Id) > 0 THEN 'Has Badges' 
            ELSE 'No Badges' 
        END AS BadgeStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (
            SELECT 
                OwnerUserId 
            FROM 
                Posts 
            WHERE 
                Id = rp.PostId
        )
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.CommentCount
),
PostVotings AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.CreationDate,
    pwb.Score,
    pwb.ViewCount,
    pwb.CommentCount,
    pwb.BadgeStatus,
    pv.UpVotes,
    pv.DownVotes,
    CASE 
        WHEN pwb.Score IS NULL THEN 'Score Not Available' 
        ELSE (SELECT CASE 
                    WHEN AVG(Score) > 100 THEN 'High' 
                    WHEN AVG(Score) BETWEEN 50 AND 100 THEN 'Medium' 
                    ELSE 'Low' 
                  END 
              FROM Posts 
              WHERE Id = pwb.PostId)
    END AS ScoreCategory
FROM 
    PostWithBadges pwb
LEFT JOIN 
    PostVotings pv ON pwb.PostId = pv.PostId
WHERE 
    pwb.CommentCount > 5 
    AND (pwb.BadgeStatus = 'Has Badges' OR pv.UpVotes > pv.DownVotes)
ORDER BY 
    pwb.CreationDate DESC, 
    pwb.CommentCount DESC,
    pwb.Score DESC 
LIMIT 50;
