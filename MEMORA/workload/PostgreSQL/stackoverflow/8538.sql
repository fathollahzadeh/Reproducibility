WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND P.Score > 0
),
MostVotedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.Score,
        COUNT(V.Id) AS VoteCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Votes V ON RP.PostId = V.PostId
    WHERE 
        RP.Rank <= 10
    GROUP BY 
        RP.PostId, RP.Title, RP.OwnerDisplayName, RP.Score
),
PostWithBadges AS (
    SELECT 
        MVP.PostId,
        MVP.Title,
        MVP.OwnerDisplayName,
        MVP.Score,
        COALESCE(B.Name, 'No Badge') AS BadgeName
    FROM 
        MostVotedPosts MVP
    LEFT JOIN 
        Badges B ON MVP.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = B.UserId)
)
SELECT 
    PWB.PostId,
    PWB.Title,
    PWB.OwnerDisplayName,
    PWB.Score,
    PWB.BadgeName,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PWB.PostId) AS CommentCount
FROM 
    PostWithBadges PWB
ORDER BY 
    PWB.Score DESC, PWB.PostId ASC;