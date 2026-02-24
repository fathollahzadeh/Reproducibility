
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        (SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate AS EditDate,
        PHT.Name AS EditType
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Name IN ('Edit Title', 'Edit Body')
),
UserBadgeDetails AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(C.Text, '; ') AS AllComments
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
FinalResults AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.UpVoteCount,
        RP.DownVoteCount,
        COALESCE(PH.UserId, 0) AS LastEditedBy,
        COALESCE(PH.EditDate, '1970-01-01 00:00:00'::timestamp) AS LastEditDate,
        COALESCE(PH.EditType, 'No Edits') AS LastEditType,
        COALESCE(UD.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(UD.BadgeNames, 'No Badges') AS UserBadges,
        COALESCE(PC.CommentCount, 0) AS TotalComments,
        COALESCE(PC.AllComments, '') AS AllComments
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistoryDetails PH ON RP.PostId = PH.PostId
    LEFT JOIN 
        UserBadgeDetails UD ON PH.UserId = UD.UserId
    LEFT JOIN 
        PostComments PC ON RP.PostId = PC.PostId
    WHERE 
        RP.Rank <= 5  
)
SELECT 
    *,
    CASE 
        WHEN UpVoteCount > DownVoteCount THEN 'Popular'
        WHEN UpVoteCount = DownVoteCount THEN 'Neutral'
        ELSE 'Unpopular'
    END AS PopularityStatus,
    CASE 
        WHEN TotalComments > 10 THEN 'Engaging Discussion'
        ELSE 'Minimal Discussion'
    END AS DiscussionLevel
FROM 
    FinalResults
WHERE 
    UserBadgeCount > 1  
ORDER BY 
    CreationDate DESC, 
    UpVoteCount DESC;
