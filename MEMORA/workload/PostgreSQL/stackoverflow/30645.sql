WITH RecursivePostCTE AS (
    SELECT 
        Id,
        ParentId,
        Title,
        Score,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY Score DESC) as Rank
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
),
PostVotes AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId IN (1, 2) 
    GROUP BY 
        P.Id
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PHT.Name = 'Edit Title' THEN PH.CreationDate END) AS LastTitleEdit,
        MAX(CASE WHEN PHT.Name = 'Post Closed' THEN PH.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN PHT.Name = 'Post Reopened' THEN PH.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
UserBadgeCount AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    P.Id AS PostId,
    P.Title,
    P.Score AS PostScore,
    PH.LastTitleEdit,
    PH.ClosedDate,
    PH.ReopenedDate,
    PV.TotalVotes,
    PV.UpVotes,
    PV.DownVotes,
    COALESCE(UBC.BadgeCount, 0) AS UserBadgeCount,
    RP.Rank AS TopAnswerRank
FROM 
    Posts P
LEFT JOIN 
    PostVotes PV ON P.Id = PV.PostId
LEFT JOIN 
    PostHistoryDetails PH ON P.Id = PH.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    UserBadgeCount UBC ON U.Id = UBC.UserId
LEFT JOIN 
    RecursivePostCTE RP ON P.AcceptedAnswerId = RP.Id
WHERE 
    P.CreationDate > '2022-01-01' 
    AND (P.Score > 5 OR P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days') 
ORDER BY 
    P.Score DESC, P.CreationDate DESC;