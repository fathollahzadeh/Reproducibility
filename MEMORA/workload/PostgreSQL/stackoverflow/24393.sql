WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.UpVotesCount,
        rp.DownVotesCount,
        CASE 
            WHEN (rp.UpVotesCount - rp.DownVotesCount) < 0 THEN 'Negative Votes'
            WHEN (rp.UpVotesCount - rp.DownVotesCount) = 0 THEN 'No Votes'
            ELSE 'Positive Votes'
        END AS VoteStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.VoteStatus,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        TopVotes tp
    JOIN 
        Users u ON tp.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.VoteStatus,
    pd.Reputation,
    pd.BadgeCount,
    CASE 
        WHEN pd.BadgeCount > 5 THEN 'Expert'
        WHEN pd.BadgeCount BETWEEN 3 AND 5 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    PostDetails pd
WHERE 
    pd.VoteStatus = 'Positive Votes'
ORDER BY 
    pd.CreationDate DESC
LIMIT 10 OFFSET 5;