WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        u.DisplayName AS UserDisplayName,
        u.Reputation
    FROM
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
TopRankedPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        UserDisplayName,
        Reputation
    FROM
        RankedPosts
    WHERE
        Rank <= 10 
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM
        Badges b
    GROUP BY
        b.UserId
),
PostVoteCounts AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY
        v.PostId
)
SELECT
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.UserDisplayName,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(pvc.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvc.DownVotes, 0) AS TotalDownVotes,
    CASE
        WHEN trp.Reputation > 1000 THEN 'High Reputation'
        ELSE 'Low Reputation'
    END AS Reputation_Category
FROM
    TopRankedPosts trp
LEFT JOIN UserBadges ub ON trp.UserDisplayName = (SELECT DisplayName FROM Users WHERE Id = ub.UserId)
LEFT JOIN PostVoteCounts pvc ON trp.PostId = pvc.PostId
ORDER BY
    trp.CreationDate DESC;