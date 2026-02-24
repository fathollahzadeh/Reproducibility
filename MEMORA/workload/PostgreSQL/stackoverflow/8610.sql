
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId IN (1, 2) 
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.CreationDate, P.ViewCount, P.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        Score,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
RecentBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    WHERE 
        B.Date >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        B.UserId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.OwnerDisplayName,
    TP.CreationDate,
    TP.ViewCount,
    TP.Score,
    TP.UpVotes,
    TP.DownVotes,
    COALESCE(RB.BadgeNames, 'No Badges') AS RecentBadges
FROM 
    TopPosts TP
LEFT JOIN 
    RecentBadges RB ON TP.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = RB.UserId)
ORDER BY 
    TP.Score DESC, TP.CreationDate DESC;
