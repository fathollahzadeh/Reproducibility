WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
), CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rb.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentBadges rb ON rp.OwnerDisplayName = (
            SELECT DisplayName FROM Users WHERE Id = rb.UserId
        )
    WHERE 
        rp.RankScore <= 5
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.Score,
    cd.ViewCount,
    cd.AnswerCount,
    cd.OwnerDisplayName,
    cd.OwnerReputation,
    COALESCE(cd.BadgeCount, 0) AS BadgeCount
FROM 
    CombinedData cd
ORDER BY 
    cd.Score DESC, cd.ViewCount DESC;